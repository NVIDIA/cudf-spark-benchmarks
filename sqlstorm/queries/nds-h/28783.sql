WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey,
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
PartNames AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        LENGTH(p.p_name) AS name_length
    FROM 
        part p
    WHERE 
        LOWER(p.p_name) LIKE '%widget%'
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.ps_partkey,
    pn.p_name,
    ps.ps_supplycost,
    s.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.order_count,
    cs.total_spent
FROM 
    partsupp ps
JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 5
JOIN 
    PartNames pn ON ps.ps_partkey = pn.p_partkey 
JOIN 
    CustomerOrders cs ON cs.order_count > 10
WHERE 
    ps.ps_availqty > 0
ORDER BY 
    pn.name_length DESC, cs.total_spent DESC;
