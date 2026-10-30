WITH RegionalSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
PartSupplied AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        pp.p_partkey,
        pp.p_name,
        pp.available_quantity,
        pp.average_supply_cost,
        rs.nation_name
    FROM 
        PartSupplied pp
    JOIN 
        RegionalSuppliers rs ON pp.available_quantity > 100
    ORDER BY 
        pp.available_quantity DESC
    LIMIT 10
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.available_quantity,
    tp.average_supply_cost,
    tp.nation_name
FROM 
    TopParts tp
WHERE 
    tp.average_supply_cost < (SELECT AVG(average_supply_cost) FROM PartSupplied)
ORDER BY 
    tp.available_quantity DESC;
