WITH  Sales_CTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
Nation_Region AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    c.c_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(nn.supplier_count, 0) AS supplier_count,
    sc.total_sales AS total_sales,
    sc.sales_rank
FROM customer c
LEFT JOIN Sales_CTE sc ON c.c_custkey = sc.c_custkey
LEFT JOIN Supplier_Summary ss ON ss.s_name = (
    SELECT s.s_name 
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_partkey = (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_availqty = (SELECT MAX(ps_availqty) FROM partsupp)
        LIMIT 1
    )
    LIMIT 1
)
LEFT JOIN Nation_Region nn ON c.c_nationkey = nn.n_nationkey
WHERE (sc.total_sales IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
  AND (sc.sales_rank <= 5 OR ss.total_supply_cost > 1000)
ORDER BY total_sales DESC, total_supply_cost DESC;
