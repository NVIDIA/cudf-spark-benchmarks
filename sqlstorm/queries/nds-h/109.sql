
WITH AverageOrderValue AS (
    SELECT 
        o_custkey, 
        AVG(o_totalprice) AS avg_order_value
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O'
    GROUP BY 
        o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        a.avg_order_value
    FROM 
        customer c
    JOIN 
        AverageOrderValue a ON c.c_custkey = a.o_custkey
    WHERE 
        a.avg_order_value > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    hvc.c_custkey, 
    hvc.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent_discounted,
    COALESCE(spd.s_name, 'None') AS supplier_name,
    COALESCE(spd.p_name, 'None') AS part_name,
    ROW_NUMBER() OVER (PARTITION BY hvc.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerOrderSummary cos ON hvc.c_custkey = cos.c_custkey
LEFT JOIN 
    orders o ON cos.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartDetails spd ON l.l_suppkey = spd.s_suppkey AND l.l_partkey = spd.p_partkey
WHERE 
    l.l_shipdate > '1997-01-01'
GROUP BY 
    hvc.c_custkey, hvc.c_name, spd.s_name, spd.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_spent_discounted DESC;
