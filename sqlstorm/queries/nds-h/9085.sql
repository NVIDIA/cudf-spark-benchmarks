
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        rs.total_value,
        ROW_NUMBER() OVER (ORDER BY rs.total_value DESC) AS rank
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.total_value > 1000000
),
CustomerRecentOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tr.s_name AS supplier_name,
    cr.c_name AS customer_name,
    cr.order_count,
    cr.total_spent,
    tr.total_value
FROM 
    TopSuppliers tr
JOIN 
    CustomerRecentOrders cr ON tr.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice < 100 OR p.p_size >= 10)
    )
ORDER BY 
    tr.total_value DESC, 
    cr.total_spent DESC
LIMIT 10;
