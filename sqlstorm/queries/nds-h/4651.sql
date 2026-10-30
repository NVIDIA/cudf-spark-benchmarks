WITH RevenueData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
),
FilteredOrders AS (
    SELECT 
        co.o_orderkey,
        co.o_orderdate,
        co.o_totalprice,
        co.c_name,
        rd.total_revenue,
        rd.supplier_count,
        ROW_NUMBER() OVER (PARTITION BY co.o_orderkey ORDER BY co.o_orderdate DESC) AS rn
    FROM 
        CustomerOrders co
    LEFT JOIN 
        RevenueData rd ON co.o_orderkey = rd.l_orderkey
)
SELECT 
    fo.o_orderkey,
    fo.o_orderdate,
    fo.o_totalprice,
    COALESCE(fo.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(fo.total_revenue, 0) AS total_revenue,
    COALESCE(fo.supplier_count, 0) AS supplier_count
FROM 
    FilteredOrders fo
WHERE 
    fo.rn = 1 AND 
    (fo.total_revenue > 1000 OR fo.total_revenue IS NULL)
ORDER BY 
    fo.o_orderdate DESC, 
    fo.o_orderkey
LIMIT 50;