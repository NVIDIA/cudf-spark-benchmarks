WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS total_returned,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE 'SMALL%')
    AND li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND EXISTS (SELECT 1 FROM HighValueCustomers hvc WHERE hvc.c_custkey = li.l_orderkey)
GROUP BY 
    p.p_name, p.p_brand, p.p_type
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 100000
ORDER BY 
    total_sales DESC;