
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '365 days'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_cost,
        MIN(ps.ps_supplycost) AS min_cost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        ps.ps_partkey
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CS.total_spent,
    RANK() OVER (ORDER BY COALESCE(rs.total_sales, 0) DESC) AS region_rank
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN 
    CustomerSummary CS ON CS.order_count > 5
WHERE 
    (CS.total_spent IS NULL OR CS.total_spent > 1000) 
    AND NOT EXISTS (
        SELECT 1 
        FROM RankedOrders oo 
        WHERE oo.o_orderkey = 1000
    )
ORDER BY 
    total_sales DESC, r.r_name ASC
LIMIT 10;
