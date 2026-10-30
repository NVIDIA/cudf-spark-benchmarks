WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
RelevantLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_returnflag,
        li.l_linestatus
    FROM 
        lineitem li
    JOIN 
        CustomerOrders co ON li.l_orderkey = co.o_orderkey
)
SELECT 
    rp.s_suppkey,
    rp.s_name,
    COUNT(DISTINCT rp.p_partkey) AS total_parts_supplied,
    SUM(rl.l_quantity) AS total_quantity_ordered,
    AVG(rl.l_extendedprice) AS avg_extended_price,
    SUM(rl.l_extendedprice * (1 - rl.l_discount)) AS total_revenue,
    SUM(rl.l_quantity * rp.ps_supplycost) AS total_cost,
    (SUM(rl.l_extendedprice * (1 - rl.l_discount)) - SUM(rl.l_quantity * rp.ps_supplycost)) AS profit
FROM 
    SupplierParts rp
JOIN 
    RelevantLineItems rl ON rp.p_partkey = rl.l_partkey
GROUP BY 
    rp.s_suppkey, rp.s_name
ORDER BY 
    profit DESC
LIMIT 10;