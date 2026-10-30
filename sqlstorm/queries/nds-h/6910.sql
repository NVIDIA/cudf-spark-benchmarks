WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name, 
        n.n_name AS nation, 
        ss.total_supply_cost
    FROM 
        SupplierStats ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
), 
OrdersSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    ts.nation, 
    os.total_revenue,
    os.o_orderdate
FROM 
    TopSuppliers ts
JOIN 
    OrdersSummary os ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'Manufacturer#1') LIMIT 1)
ORDER BY 
    os.total_revenue DESC;
