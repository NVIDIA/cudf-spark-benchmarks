
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
), TopProducts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS average_discount
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_partkey
), SupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pr.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region pr ON n.n_regionkey = pr.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name, pr.r_name
)
SELECT 
    tp.l_partkey,
    sp.p_name,
    sd.region_name,
    tp.total_quantity,
    tp.average_discount,
    sd.total_supply_cost
FROM 
    TopProducts tp
JOIN 
    SupplierDetails sd ON tp.l_partkey = sd.p_partkey
JOIN 
    part sp ON tp.l_partkey = sp.p_partkey
WHERE 
    tp.total_quantity > 100
ORDER BY 
    sd.total_supply_cost DESC, tp.total_quantity DESC;
