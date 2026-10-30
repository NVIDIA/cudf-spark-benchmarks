
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    fs.nation,
    ARRAY_AGG(DISTINCT fs.s_name) AS top_suppliers,
    COUNT(os.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_revenue_collected
FROM 
    FilteredSuppliers fs
LEFT JOIN 
    OrderSummary os ON fs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_orderkey IN (
            SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
        )
    )
GROUP BY 
    fs.nation
ORDER BY 
    total_revenue_collected DESC;
