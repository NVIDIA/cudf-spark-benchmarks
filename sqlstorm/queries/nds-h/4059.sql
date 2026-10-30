
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'AFRICA'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY c.avg_order_value DESC) AS customer_rank
    FROM 
        CustomerOrders c
)
SELECT 
    r.region_name,
    t.c_name,
    t.avg_order_value,
    r.total_sales
FROM 
    RegionalSales r
FULL OUTER JOIN 
    TopCustomers t ON r.region_name LIKE '%' || t.c_name || '%'
WHERE 
    (t.avg_order_value IS NOT NULL AND r.total_sales IS NOT NULL)
    OR (t.avg_order_value IS NULL AND r.total_sales IS NULL)
ORDER BY 
    r.total_sales DESC, t.avg_order_value DESC;
