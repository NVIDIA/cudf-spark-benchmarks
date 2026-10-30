WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_type LIKE '%metal%'
),
ValidSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_name
)
SELECT 
    cp.p_name,
    cp.p_brand,
    co.o_orderkey,
    co.o_totalprice,
    vs.total_supply_cost,
    vs.part_count,
    RANK() OVER (PARTITION BY cp.p_brand ORDER BY co.o_totalprice DESC) AS order_value_rank
FROM 
    RankedParts cp
LEFT JOIN 
    ValidSuppliers vs ON vs.part_count > 5
JOIN 
    CustomerOrders co ON co.line_count > 0
WHERE 
    cp.price_rank <= 10 AND 
    co.o_totalprice > (SELECT AVG(o_totalprice) FROM CustomerOrders)
ORDER BY 
    cp.p_brand, order_value_rank;