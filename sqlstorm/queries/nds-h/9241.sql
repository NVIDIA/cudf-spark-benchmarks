WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    SUM(os.total_revenue) AS total_revenue,
    AVG(rs.total_supply_cost) AS avg_supplier_cost,
    SUM(CASE WHEN rs.supplier_rank = 1 THEN rs.total_supply_cost ELSE 0 END) AS max_supplier_cost
FROM 
    nation n
JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
JOIN 
    OrderSummary os ON cs.c_custkey = os.o_orderkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part pp ON pp.p_partkey = ps.ps_partkey
        WHERE pp.p_type LIKE '%metal%' 
    )
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC, total_customers ASC
LIMIT 10;