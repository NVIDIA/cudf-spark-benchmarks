
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
        AND o.o_orderdate >= DATE '1996-01-01'
),
KeyPartSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > (
            SELECT 
                AVG(ps_supplycost) 
            FROM 
                partsupp 
            WHERE 
                ps_supplycost IS NOT NULL
        )
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    c.c_name AS customer_name,
    s_rank.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice), CAST(0.00 AS DECIMAL)) AS total_extended_price,
    s_rank.total_supply_cost AS supplier_cost,
    CASE 
        WHEN s_rank.rank = 1 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_tier
FROM 
    CustomerOrders co
JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
JOIN 
    RankedSuppliers s_rank ON l.l_suppkey = s_rank.s_suppkey
JOIN 
    KeyPartSuppliers ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON co.c_custkey = c.c_custkey
WHERE 
    s_rank.total_supply_cost > 10000
GROUP BY 
    c.c_name, s_rank.s_name, p.p_name, s_rank.total_supply_cost, s_rank.rank
ORDER BY 
    total_extended_price DESC, c.c_name;
