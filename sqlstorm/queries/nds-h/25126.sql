WITH AggregatedData AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        c.c_name AS customer_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY p.p_partkey, p.p_name, s.s_name, c.c_name
), RankedData AS (
    SELECT 
        *, 
        RANK() OVER (PARTITION BY supplier_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM AggregatedData
)
SELECT 
    p_partkey, 
    p_name, 
    supplier_name, 
    customer_name, 
    total_revenue, 
    order_count, 
    avg_quantity
FROM RankedData
WHERE revenue_rank <= 10
ORDER BY supplier_name, total_revenue DESC;