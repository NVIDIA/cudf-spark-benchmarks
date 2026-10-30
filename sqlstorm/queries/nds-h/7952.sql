WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), 
RegionSupply AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, SUM(ps.ps_availqty) AS total_available
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name
)
SELECT rp.p_name, rp.total_cost, rs.nation_name, rs.region_name, rs.total_available
FROM RankedParts rp
JOIN RegionSupply rs ON rs.region_name = (SELECT r_name FROM region ORDER BY r_regionkey LIMIT 1)
WHERE rp.total_cost > (SELECT AVG(total_cost) FROM RankedParts)
ORDER BY rp.total_cost DESC, rs.total_available DESC
LIMIT 10;
