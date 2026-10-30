WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),

CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),

SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),

ProductInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 15 AND 30
),

SalesRanks AS (
    SELECT 
        cs.c_custkey,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.order_count > 5
),

ExcessiveOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.rn
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 3
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(s.total_avail_qty, 0) AS available_quantity,
    COALESCE(sr.sales_rank, 0) AS customer_sales_rank,
    (CASE 
        WHEN s.total_avail_qty IS NULL THEN 'Supplier not available' 
        ELSE 'In stock' 
    END) AS stock_status,
    (SELECT 
        COUNT(*) 
     FROM 
        ExcessiveOrders eo 
     WHERE 
        eo.o_orderdate BETWEEN '1996-01-01' AND '1997-01-01' AND 
        eo.o_totalprice > 1000
    ) AS high_value_order_count
FROM 
    ProductInfo p
LEFT JOIN 
    SupplierAvailability s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    SalesRanks sr ON p.p_partkey = sr.c_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) AND
    (SELECT COUNT(*) FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%West%')) > 0
ORDER BY 
    p.p_partkey, p.p_name;