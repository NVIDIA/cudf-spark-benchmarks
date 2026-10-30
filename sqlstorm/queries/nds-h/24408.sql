
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
NationalSuppliers AS (
    SELECT 
        n.n_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
),
LoyalCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
),
Summary AS (
    SELECT 
        no.n_name,
        COALESCE(lc.c_name, 'No Customers') AS customer_name,
        lc.order_count,
        lc.total_spent,
        no.total_available_qty
    FROM NationalSuppliers no
    LEFT JOIN LoyalCustomers lc ON no.n_name = lc.c_name
)
SELECT 
    s.n_name AS nation_name,
    s.customer_name,
    s.order_count,
    s.total_spent,
    s.total_available_qty,
    CASE 
        WHEN s.total_spent IS NULL THEN 'No Spending'
        WHEN s.total_spent > 10000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type
FROM Summary s
FULL OUTER JOIN RankedOrders ro ON s.order_count IS NOT NULL AND ro.o_orderkey IS NOT NULL
WHERE (s.customer_name IS NOT NULL OR s.total_available_qty IS NULL)
AND (EXTRACT(YEAR FROM ro.o_orderdate) >= 1994 OR s.n_name IS NOT NULL)
ORDER BY 
    s.total_spent DESC NULLS LAST,
    s.n_name ASC,
    ro.o_orderkey;
