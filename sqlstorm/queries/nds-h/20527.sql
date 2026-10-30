WITH  customer_rank AS (
    SELECT c_custkey, c_name, c_acctbal, ROW_NUMBER() OVER (ORDER BY c_acctbal DESC) AS rank
    FROM customer
    WHERE c_acctbal IS NOT NULL
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
nation_regions AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
),
complex_query AS (
    SELECT 
        cr.c_custkey,
        cr.c_name,
        cr.rank,
        sd.s_name AS supplier_name,
        sd.total_supply_value,
        COALESCE(ls.total_line_value, 0) AS total_line_value
    FROM customer_rank cr
    LEFT JOIN nation n ON cr.c_custkey % 5 = n.n_nationkey % 5  
    LEFT JOIN supplier_details sd ON n.n_nationkey = sd.s_nationkey
    LEFT JOIN lineitem_summary ls ON ls.l_orderkey = cr.c_custkey * 10  
    WHERE cr.rank <= 100 AND (sd.total_supply_value IS NULL OR sd.total_supply_value > 10000.00)
)
SELECT 
    cqr.c_custkey,
    cqr.c_name,
    cqr.rank,
    cqr.supplier_name,
    cqr.total_supply_value,
    cqr.total_line_value,
    CASE 
        WHEN cqr.total_line_value IS NULL THEN 'No Orders'
        WHEN cqr.total_line_value > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_value_category,
    STRING_AGG(CONCAT(n.n_name, ' (', r.r_name, ')'), '; ') FILTER (WHERE n.n_nationkey IS NOT NULL) AS associated_nations
FROM complex_query cqr
LEFT JOIN nation_regions n ON n.n_nationkey = cqr.c_custkey % 25  
LEFT JOIN region r ON n.region_name = r.r_name
GROUP BY cqr.c_custkey, cqr.c_name, cqr.rank, cqr.supplier_name, cqr.total_supply_value, cqr.total_line_value
ORDER BY cqr.rank DESC, cqr.total_supply_value DESC NULLS LAST;