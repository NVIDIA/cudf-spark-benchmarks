WITH  NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    GROUP BY 
        n.n_nationkey, n.n_name
),
TopNations AS (
    SELECT 
        n_nationkey, n_name, total_sales, sales_rank
    FROM 
        NationSales
    WHERE 
        sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, c.c_name, co.total_order_value
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_order_value > (
            SELECT 
                AVG(total_order_value) 
            FROM 
                CustomerOrders
        )
)
SELECT 
    tn.n_name, 
    tn.total_sales, 
    hvc.c_name, 
    hvc.total_order_value
FROM 
    TopNations tn
LEFT JOIN 
    HighValueCustomers hvc ON tn.n_nationkey = hvc.c_custkey
ORDER BY 
    tn.total_sales DESC, 
    hvc.total_order_value DESC;
