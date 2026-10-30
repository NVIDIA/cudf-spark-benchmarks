WITH Name_Nation AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, p.p_mfgr, p.p_type
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
Sales_Summary AS (
    SELECT o.o_orderkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
),
Combined AS (
    SELECT nn.nation_name, ss.c_name, ss.total_sales, nn.p_mfgr, nn.p_type
    FROM Name_Nation nn
    JOIN Sales_Summary ss ON nn.s_suppkey = ss.o_orderkey 
)
SELECT nation_name, p_mfgr, p_type, COUNT(DISTINCT c_name) AS customer_count, SUM(total_sales) AS total_sales_sum
FROM Combined
GROUP BY nation_name, p_mfgr, p_type
ORDER BY nation_name, total_sales_sum DESC
LIMIT 10;