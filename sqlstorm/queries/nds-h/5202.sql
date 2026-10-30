WITH NationSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p 
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    ns.nation_name,
    ns.supplier_count,
    ns.total_account_balance,
    pp.p_name,
    pp.total_quantity_sold
FROM 
    NationSuppliers ns
CROSS JOIN 
    PopularParts pp
ORDER BY 
    ns.nation_name, pp.total_quantity_sold DESC;