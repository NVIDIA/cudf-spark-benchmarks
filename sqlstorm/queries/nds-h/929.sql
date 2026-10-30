WITH RankedSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l_partkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM 
        lineitem
    GROUP BY 
        l_partkey
),
HighVolumeSuppliers AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_availqty) AS total_available_qty
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, ps_suppkey
    HAVING 
        SUM(ps_availqty) > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    p.p_name,
    r.r_name AS supplier_region,
    COALESCE(HighVolume.total_available_qty, 0) AS available_quantity,
    Sales.total_sales,
    CASE 
        WHEN Sales.sales_rank = 1 THEN 'Top Seller' 
        ELSE 'Regular' 
    END AS sales_status,
    COALESCE(cust.total_spent, 0) AS customer_spending
FROM 
    part p
LEFT JOIN 
    RankedSales Sales ON p.p_partkey = Sales.l_partkey
LEFT JOIN 
    HighVolumeSuppliers HighVolume ON p.p_partkey = HighVolume.ps_partkey
LEFT JOIN 
    supplier s ON HighVolume.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders cust ON cust.c_custkey = (
        SELECT c_custkey 
        FROM customer 
        ORDER BY c_acctbal DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND Sales.total_sales IS NOT NULL
ORDER BY 
    Sales.total_sales DESC, 
    p.p_name;
