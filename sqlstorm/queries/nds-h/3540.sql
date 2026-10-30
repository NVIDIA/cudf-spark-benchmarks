WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
SalesSummary AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        l.l_orderkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name, r.r_name
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    SUM(ss.total_sales) AS total_sales,
    AVG(ss.total_sales) AS avg_sales_per_order,
    MAX(ss.total_sales) AS max_order_sales,
    MIN(ss.total_sales) AS min_order_sales,
    CASE 
        WHEN SUM(ss.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    CustomerRegions cr
LEFT JOIN 
    SalesSummary ss ON cr.c_custkey = ss.l_orderkey
WHERE 
    cr.total_sales > 1000
GROUP BY 
    cr.region_name, cr.nation_name
HAVING 
    COUNT(DISTINCT cr.c_custkey) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;