
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(tli.total_price, 0) AS total_order_value,
    rs.s_name AS top_supplier,
    rs.s_acctbal AS top_supplier_balance
FROM 
    CustomerOrders co
LEFT JOIN 
    TotalLineItems tli ON co.o_orderkey = tli.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1
WHERE 
    (co.c_name LIKE 'A%' OR co.c_name LIKE 'B%') AND 
    (tli.total_price IS NOT NULL OR (co.o_orderkey IS NULL AND rs.s_acctbal > 1000))
ORDER BY 
    total_order_value DESC, 
    co.c_custkey ASC
LIMIT 100;
