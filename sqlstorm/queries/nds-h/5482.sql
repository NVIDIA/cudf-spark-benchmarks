
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_custkey,
        c.c_mktsegment,
        l.l_partkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
HighValueLineItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    ps.ps_partkey, 
    p.p_name, 
    SUM(ps.ps_availqty) AS total_avail_qty,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    rs.nation_name
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    HighValueLineItems hvli ON hvli.l_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
JOIN 
    FilteredOrders fo ON fo.l_partkey = ps.ps_partkey
WHERE 
    rs.rank <= 5
GROUP BY 
    ps.ps_partkey, p.p_name, rs.nation_name
ORDER BY 
    total_supply_cost DESC;
