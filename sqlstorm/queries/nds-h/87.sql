
WITH RegionalSales AS (
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
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), RankedCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS spend_rank
    FROM 
        CustomerOrders cust
)

SELECT 
    r.region_name,
    rc.c_name,
    rc.total_spent,
    (CASE 
        WHEN rc.total_spent IS NOT NULL THEN 'Active Customer' 
        ELSE 'No Orders' 
     END) AS customer_status,
    (SELECT COUNT(*) 
     FROM lineitem l 
     WHERE l.l_shipdate > DATE '1998-10-01' - INTERVAL '30 days') AS recent_shipments
FROM 
    RegionalSales r
FULL OUTER JOIN 
    RankedCustomers rc ON r.region_name = rc.c_name
WHERE 
    (rc.spend_rank IS NOT NULL AND rc.total_spent > 1000) OR r.total_sales IS NULL
ORDER BY 
    r.total_sales DESC NULLS LAST, rc.total_spent DESC;
