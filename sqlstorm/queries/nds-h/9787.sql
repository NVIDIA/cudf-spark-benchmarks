
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost
    FROM 
        RankedSuppliers ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ss.rnk <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        ts.s_name,
        ts.total_supply_cost
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    COUNT(DISTINCT od.l_partkey) AS distinct_parts,
    SUM(od.l_extendedprice) AS total_extended_price,
    AVG(od.total_supply_cost) AS avg_supply_cost_per_order
FROM 
    OrderDetails od
GROUP BY 
    od.o_orderkey, od.o_orderdate
ORDER BY 
    total_extended_price DESC
LIMIT 10;
