WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.s_name,
    cs.c_name AS top_customer,
    cs.total_spent,
    rs.total_supply_value
FROM 
    RankedSuppliers rs
JOIN 
    CustomerSpending cs ON rs.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_totalprice > 50000 
        GROUP BY 
            ps.ps_suppkey 
        ORDER BY 
            SUM(l.l_extendedprice * (1 - l.l_discount)) DESC 
        LIMIT 1
    )
WHERE 
    rs.supplier_rank <= 10
ORDER BY 
    rs.total_supply_value DESC, cs.total_spent DESC;
