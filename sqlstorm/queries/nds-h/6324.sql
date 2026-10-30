WITH OrderedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        os.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY os.total_supply_cost DESC) AS rank
    FROM OrderedSuppliers os
    JOIN supplier s ON os.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal,
    ts.total_supply_cost,
    CASE 
        WHEN ts.rank <= 10 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category
FROM TopSuppliers ts
WHERE ts.rank <= 20
ORDER BY ts.total_supply_cost DESC;
