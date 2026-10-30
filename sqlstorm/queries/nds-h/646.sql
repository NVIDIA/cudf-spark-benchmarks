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
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
CustomerRegionSales AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, n.n_regionkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    COALESCE(sp.total_available_quantity, 0) AS available_quantity,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales < 5000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_status
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerRegionSales cs ON cs.n_regionkey = (
        SELECT 
            r.r_regionkey 
        FROM 
            region r
        WHERE 
            r.r_name = 'Europe'
        LIMIT 1
    )
WHERE 
    p.p_size = 15 AND 
    (p.p_retailprice BETWEEN 100 AND 200 OR p.p_comment LIKE '%special%')
ORDER BY 
    available_quantity DESC, sales_status
LIMIT 100;