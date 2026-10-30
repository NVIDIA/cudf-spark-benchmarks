
WITH CustomerStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT
        cust.c_custkey,
        cust.c_name,
        cust.order_count,
        cust.total_spent,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS rank
    FROM
        CustomerStats cust
    WHERE
        cust.total_spent > 1000
),
NationalStats AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    cs.order_count,
    cs.total_spent,
    ss.parts_supplied,
    ss.avg_supply_cost,
    ns.supplier_count,
    ns.total_supply_cost
FROM 
    TopCustomers cs
FULL OUTER JOIN SupplierStats ss ON MOD(cs.order_count, 10) = MOD(ss.parts_supplied, 10)
JOIN NationalStats ns ON ss.parts_supplied > ns.supplier_count
LEFT JOIN customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN supplier s ON ss.s_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE
    (c.c_acctbal IS NULL OR c.c_acctbal > 500) AND
    (ss.parts_supplied NOT IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost IS NULL) OR ns.total_supply_cost < 5000)
ORDER BY 
    cs.total_spent DESC, 
    ss.avg_supply_cost ASC;
