
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),

TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_line_items
    FROM lineitem l
    GROUP BY l.l_orderkey
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        t.total_line_items,
        CASE 
            WHEN t.total_line_items >= 5 THEN 'High'
            WHEN t.total_line_items BETWEEN 3 AND 4 THEN 'Medium'
            ELSE 'Low'
        END AS order_value_category
    FROM orders o
    JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
    WHERE o.o_totalprice > 1000
),

SupplierStats AS (
    SELECT 
        ns.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM nation ns
    LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    GROUP BY ns.n_name
),

OrderSupplierAssociation AS (
    SELECT 
        o.o_orderkey,
        s.s_name,
        COUNT(*) AS supplier_count,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY o.o_orderkey, s.s_name
)

SELECT 
    rs.s_name,
    o.o_orderkey,
    o.o_totalprice,
    o.order_value_category,
    os.supplier_count,
    os.total_supply_cost,
    n.n_name AS supplier_nation
FROM HighValueOrders o
JOIN OrderSupplierAssociation os ON o.o_orderkey = os.o_orderkey
JOIN supplier s ON os.s_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE 
    o.order_value_category = 'High' 
    AND NOT EXISTS (
        SELECT 1 
        FROM orders oo 
        WHERE oo.o_orderkey = o.o_orderkey AND oo.o_totalprice < 1000
    )
ORDER BY 
    o.o_totalprice DESC, rs.rank ASC
LIMIT 10;
