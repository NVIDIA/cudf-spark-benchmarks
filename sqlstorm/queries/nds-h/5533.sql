WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey 
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 100
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rc.c_name,
    tn.n_name,
    ps.total_supply_value,
    ps.supplier_count,
    rc.total_spent
FROM 
    RankedCustomers rc
JOIN 
    customer c ON rc.c_custkey = c.c_custkey
JOIN 
    nation tn ON c.c_nationkey = tn.n_nationkey
JOIN 
    PartSupplierStats ps ON c.c_custkey % 10 = ps.ps_partkey % 10
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_spent DESC, tn.n_name ASC;