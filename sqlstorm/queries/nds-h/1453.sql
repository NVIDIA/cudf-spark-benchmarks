WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        r.* 
    FROM 
        RankedOrders r 
    WHERE 
        r.rn <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_name,
    COALESCE(ps.order_count, 0) AS part_order_count,
    COALESCE(ps.avg_price, 0) AS avg_part_price,
    sd.s_name AS supplier_name,
    sd.total_supply_cost
FROM 
    TopOrders o
LEFT JOIN 
    PartStats ps ON o.o_orderkey = ps.p_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.p_partkey = sd.ps_partkey
WHERE 
    o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    o.o_totalprice DESC;