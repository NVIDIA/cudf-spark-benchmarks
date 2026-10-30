
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        ps.ps_supplycost / NULLIF(ps.ps_availqty, 0) AS supply_cost_per_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent,
        ROW_NUMBER() OVER (ORDER BY cust.total_spent DESC) AS cust_rank
    FROM CustomerOrders cust
    WHERE cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders) 
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    sp.p_name,
    sp.s_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    hvc.c_name AS high_value_cust,
    COALESCE(sp.p_retailprice, 0) - COALESCE(sp.supply_cost_per_qty, 0) AS profit_margin 
FROM RankedOrders r
LEFT JOIN SupplierPartDetails sp ON r.o_orderkey = sp.p_partkey
LEFT JOIN HighValueCustomers hvc ON sp.s_suppkey = hvc.c_custkey
WHERE r.order_rank <= 10
  AND (r.o_orderdate IS NOT NULL OR r.o_orderkey IS NOT NULL)
ORDER BY r.o_orderdate DESC, profit_margin DESC;
