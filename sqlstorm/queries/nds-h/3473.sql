
WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name
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
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.order_count,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rnk
    FROM 
        CustomerOrders c
)

SELECT 
    rs.region_name,
    rc.c_name,
    rc.order_count,
    rc.total_spent,
    CASE 
        WHEN rc.total_spent IS NULL THEN 'No Orders'
        WHEN rc.total_spent > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    RegionSales rs
FULL OUTER JOIN 
    RankedCustomers rc ON rc.rnk <= 5
WHERE 
    rs.total_sales IS NOT NULL OR rc.c_name IS NOT NULL
ORDER BY 
    rs.total_sales DESC, rc.total_spent DESC
LIMIT 10;
