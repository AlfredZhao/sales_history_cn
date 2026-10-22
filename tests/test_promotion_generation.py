"""Offline calendar/reference and source-wiring tests (not Oracle execution).

Run from the repo root: python3 -m unittest discover -s tests -v
Run oracle_promotion_generation.sql separately to exercise the real PL/SQL,
ORA_HASH, multiset equality, and validation failures on Oracle.
"""

import calendar
from datetime import date, timedelta
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "sales_history"
NO_PROMO = (date.min, date.max)


def campaigns(start, end):
    """Reference for ensure_promotions: entire months, fixed IDs/windows."""
    result = {999: NO_PROMO}
    first = (start.year - 1) * 12 + start.month - 1
    last = (end.year - 1) * 12 + end.month - 1
    for month_index in range(first, last + 1):
        year, month = month_index // 12 + 1, month_index % 12 + 1
        end_day = calendar.monthrange(year, month)[1]
        for kind, (begin, finish) in enumerate(((1, 14), (8, 21), (18, end_day))):
            result[1000 + month_index * 3 + kind] = (
                date(year, month, begin), date(year, month, finish)
            )
    return result


def candidates(promos, day):
    return sorted(key for key, (begin, end) in promos.items() if begin <= day <= end)


def days(start, end):
    for offset in range((end - start).days + 1):
        yield start + timedelta(days=offset)


def quota(day):
    day_index = (day - date(day.year, 1, 1)).days
    year_days = 366 if calendar.isleap(day.year) else 365
    return (day_index + 1) * 200000 // year_days - day_index * 200000 // year_days


class CalendarTests(unittest.TestCase):
    def test_every_day_has_only_valid_candidates_including_no_promotion(self):
        start, end = date(2023, 1, 1), date(2030, 12, 31)
        promos = campaigns(start, end)
        self.assertEqual(len(promos), 8 * 12 * 3 + 1)
        for day in days(start, end):
            available = candidates(promos, day)
            self.assertIn(999, available)
            self.assertIn(len(available), (2, 3))
            # Any hash modulo the candidate count selects a valid campaign.
            for key in available:
                begin, finish = promos[key]
                self.assertLessEqual(begin, day)
                self.assertGreaterEqual(finish, day)

    def test_boundaries_are_inclusive(self):
        promos = campaigns(date(2026, 10, 1), date(2026, 10, 31))
        for key, (begin, end) in promos.items():
            if key == 999:
                continue
            self.assertIn(key, candidates(promos, begin))
            self.assertIn(key, candidates(promos, end))
            self.assertNotIn(key, candidates(promos, begin - timedelta(days=1)))
            self.assertNotIn(key, candidates(promos, end + timedelta(days=1)))

    def test_partial_month_does_not_truncate_campaigns(self):
        self.assertEqual(
            campaigns(date(2026, 10, 10), date(2026, 10, 10)),
            campaigns(date(2026, 10, 1), date(2026, 10, 31)),
        )

    def test_leap_day_and_month_end(self):
        for year, last_day in ((2023, 28), (2024, 29), (2100, 28), (2400, 29)):
            day = date(year, 2, last_day)
            promos = campaigns(day, day)
            self.assertEqual(len(candidates(promos, day)), 2)
            regular = [interval for key, interval in promos.items() if key != 999]
            self.assertEqual(max(end for _, end in regular), day)

    def test_full_range_equals_segmented_generation(self):
        start, end = date(2023, 12, 29), date(2024, 3, 2)
        full = campaigns(start, end)
        partial = {}
        next_start = start
        for stop in (date(2024, 1, 14), date(2024, 2, 28), date(2024, 2, 29), end):
            before = partial.copy()
            # MERGE WHEN NOT MATCHED: never update existing rows.
            for key, interval in campaigns(next_start, stop).items():
                partial.setdefault(key, interval)
            for key, interval in before.items():
                self.assertEqual(partial[key], interval)
            for day in days(next_start, stop):
                self.assertEqual(candidates(partial, day), candidates(full, day))
            next_start = stop + timedelta(days=1)
        self.assertEqual(partial, full)

    def test_future_months_do_not_change_historical_candidates(self):
        start, end = date(2026, 10, 1), date(2026, 10, 22)
        old = campaigns(start, end)
        extended = campaigns(start, date(2035, 12, 31))
        for day in days(start, end):
            self.assertEqual(candidates(old, day), candidates(extended, day))

    def test_id_bounds_and_no_sentinel_collision(self):
        earliest = campaigns(date(1, 1, 1), date(1, 1, 31))
        latest = campaigns(date(9999, 12, 1), date(9999, 12, 31))
        self.assertEqual(min(key for key in earliest if key != 999), 1000)
        self.assertEqual(max(latest), 360963)
        self.assertLess(max(latest), 1000000)

    def test_daily_quotas_preserve_annual_volume(self):
        for year in (2023, 2024, 2026, 2100, 2400):
            quotas = [quota(day) for day in days(date(year, 1, 1), date(year, 12, 31))]
            self.assertEqual(sum(quotas), 200000)
            self.assertGreater(min(quotas), 0)
            self.assertLessEqual(max(quotas), 600)


class SourceWiringTests(unittest.TestCase):
    def test_both_entrypoints_use_shared_generator_before_commit(self):
        for filename in ("sh_generate.sql", "sh_append.sql"):
            source = (SQL / filename).read_text()
            self.assertEqual(source.count("sh_data_generation.generate_facts("), 1)
            self.assertNotIn("INSERT INTO sales", source)
            self.assertNotIn("v_promo_count", source)
            self.assertLess(source.index("sh_data_generation.generate_facts("),
                            source.index("DBMS_MVIEW.REFRESH("))
            self.assertIn("ROLLBACK;", source)

    def test_legacy_promotions_are_not_loaded_or_relocalized(self):
        populate = (SQL / "sh_populate.sql").read_text()
        self.assertNotIn("LOAD promotions promotions.csv", populate)
        self.assertLess(populate.index("@@sh_data_generation.sql"),
                        populate.index("@@sh_generate.sql"))
        self.assertNotIn("UPDATE promotions", (SQL / "sh_generate.sql").read_text())
        self.assertNotIn('503 AS "provided"', (SQL / "sh_install.sql").read_text())

    def test_shared_generator_has_date_aware_selection_and_validation(self):
        source = (SQL / "sh_data_generation.sql").read_text()
        self.assertIn("d.time_id BETWEEN p.promo_begin_date AND p.promo_end_date", source)
        self.assertIn("pr.time_id = r.time_id AND pr.promo_rn = r.promo_rn", source)
        self.assertIn("MOD(ORA_HASH(row_key || ':R', 999999), promo_count)", source)
        self.assertIn("CASE WHEN pr.promo_id = 999 THEN 100", source)
        self.assertEqual(source.count("WHEN NOT MATCHED THEN INSERT"), 2)
        self.assertNotIn("WHEN MATCHED", source)
        self.assertIn("LEFT JOIN promotions", source)
        self.assertIn("NVL(s.row_count, 0)", source)
        self.assertIn("validate_range(p_start_date, p_end_date);", source)
        # Ignore comments; the shared package must not commit caller work.
        statements = "\n".join(line.split("--", 1)[0] for line in source.splitlines())
        self.assertNotIn("COMMIT;", statements.upper())


if __name__ == "__main__":
    unittest.main()
