WITH SupplierProfit AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
ProfitAnalysis AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.total_revenue - s.total_supply_cost AS profit
    FROM SupplierProfit s
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT pa.s_suppkey) AS supplier_count,
    SUM(pa.profit) AS total_profit
FROM ProfitAnalysis pa
JOIN supplier s ON pa.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY total_profit DESC
LIMIT 5;
