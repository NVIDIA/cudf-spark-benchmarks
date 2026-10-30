WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
CustomerStatus AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    rs.o_orderkey,
    cs.c_name,
    cs.total_spent,
    tp.p_name,
    tp.revenue,
    COALESCE(sp.part_count, 0) AS supplier_part_count,
    COALESCE(sp.total_supplycost, 0) AS total_supplycost,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    RankedOrders rs
JOIN 
    CustomerStatus cs ON rs.o_orderkey = cs.order_count
LEFT JOIN 
    TopParts tp ON rs.o_orderkey = tp.p_partkey
LEFT JOIN 
    SupplierParts sp ON tp.p_partkey = sp.part_count
WHERE 
    rs.rn <= 5 AND
    (rs.o_orderstatus = 'O' OR rs.o_orderstatus IS NULL)
ORDER BY 
    rs.o_orderdate DESC, cs.total_spent DESC;