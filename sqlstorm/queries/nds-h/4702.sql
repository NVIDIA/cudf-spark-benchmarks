
WITH RegionalSales AS (
    SELECT 
        r.r_name,
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
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_name
),
SuccessRate AS (
    SELECT 
        l.l_shipmode,
        COUNT(l.l_orderkey) AS shipped_orders,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_orders,
        AVG(CASE WHEN l.l_returnflag = 'R' THEN 1.0 ELSE 0 END) AS return_rate
    FROM 
        lineitem l
    GROUP BY 
        l.l_shipmode
)
SELECT 
    rs.r_name,
    rs.total_sales,
    co.c_name,
    co.order_count,
    co.avg_order_value,
    sr.l_shipmode,
    sr.shipped_orders,
    sr.returned_orders,
    sr.return_rate
FROM 
    RegionalSales rs
FULL OUTER JOIN 
    CustomerOrders co ON rs.r_name IS NOT NULL
FULL OUTER JOIN 
    SuccessRate sr ON sr.l_shipmode IS NOT NULL
ORDER BY 
    rs.total_sales DESC, 
    co.order_count DESC, 
    sr.return_rate ASC;
