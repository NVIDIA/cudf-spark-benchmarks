WITH DetailedInfo AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_name LIKE '%widget%'
        AND o.o_orderdate > '1997-01-01'
),
FilteredDetails AS (
    SELECT 
        part_name,
        supplier_name,
        customer_name,
        order_date,
        total_price
    FROM 
        DetailedInfo
    WHERE 
        rn = 1
)
SELECT 
    part_name,
    supplier_name,
    customer_name,
    COUNT(*) AS total_orders,
    SUM(total_price) AS total_revenue
FROM 
    FilteredDetails
GROUP BY 
    part_name, supplier_name, customer_name
ORDER BY 
    total_revenue DESC;