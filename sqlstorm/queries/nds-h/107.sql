
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_orders,
        cs.avg_order_value
    FROM 
        customer c
    JOIN 
        CustomerStats cs ON c.c_custkey = cs.c_custkey
    WHERE 
        cs.avg_order_value > (SELECT AVG(avg_order_value) FROM CustomerStats)
)
SELECT 
    rs.region_name,
    COALESCE(hvc.c_name, 'No High Value Customers') AS high_value_customer_name,
    COALESCE(hvc.total_orders, 0) AS total_orders,
    COALESCE(hvc.avg_order_value, 0) AS avg_order_value,
    rs.total_sales
FROM 
    RegionalSales rs
LEFT JOIN 
    HighValueCustomers hvc ON rs.region_name IN (
        SELECT 
            n.n_name 
        FROM 
            nation n 
        JOIN 
            supplier s ON n.n_nationkey = s.s_nationkey 
        JOIN 
            partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey 
        JOIN 
            lineitem l ON p.p_partkey = l.l_partkey 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        JOIN 
            customer c ON o.o_custkey = c.c_custkey 
        WHERE 
            l.l_shipdate >= DATE '1997-01-01' 
            AND l.l_shipdate < DATE '1998-01-01'
        GROUP BY 
            n.n_name
    )
ORDER BY 
    rs.total_sales DESC, hvc.avg_order_value DESC;
