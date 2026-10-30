
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
TopOrders AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ro.o_totalprice) AS total_sales,
        COUNT(ro.o_orderkey) AS order_count
    FROM 
        RankedOrders ro
    JOIN 
        supplier s ON EXISTS (
            SELECT 1 FROM partsupp ps 
            WHERE ps.ps_partkey IN (
                SELECT p.p_partkey 
                FROM part p 
                WHERE p.p_brand = 'Brand#1'
            ) AND ps.ps_suppkey = s.s_suppkey
        )
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tr.r_regionkey,
    tr.r_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.order_count, 0) AS order_count
FROM 
    region tr
LEFT JOIN 
    TopOrders t ON tr.r_regionkey = t.r_regionkey
ORDER BY 
    tr.r_regionkey;
