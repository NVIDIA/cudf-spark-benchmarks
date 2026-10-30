
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(ps_supplycost)
            FROM partsupp
        )
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        COALESCE(c.c_name, 'Unknown') AS customer_name
    FROM 
        RankedOrders ro
        LEFT JOIN customer c ON ro.o_orderkey = c.c_custkey  
    WHERE 
        ro.rn = 1 
        AND ro.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 month'
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    lineitem li
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    JOIN supplier s ON li.l_suppkey = s.s_suppkey
    JOIN partsupp ps ON li.l_partkey = ps.ps_partkey AND li.l_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN RecentOrders ro ON o.o_orderkey = ro.o_orderkey
WHERE 
    li.l_shipdate >= DATE '1997-01-01'
    AND (li.l_returnflag = 'N' OR li.l_returnflag IS NULL)
GROUP BY 
    r.r_name,
    n.n_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > (
        SELECT AVG(total_sales)
        FROM (
            SELECT SUM(li2.l_extendedprice * (1 - li2.l_discount)) AS total_sales
            FROM lineitem li2
            JOIN orders o2 ON li2.l_orderkey = o2.o_orderkey
            GROUP BY o2.o_orderkey
        ) AS avg_sales
    )
ORDER BY 
    total_sales DESC
LIMIT 10;
