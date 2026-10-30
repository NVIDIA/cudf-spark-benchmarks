WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ProductPopularity AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedCustomers AS (
    SELECT *, RANK() OVER (ORDER BY total_spent DESC) AS rank_spent
    FROM CustomerOrders
),
RankedProducts AS (
    SELECT *, RANK() OVER (ORDER BY total_quantity DESC) AS rank_quantity
    FROM ProductPopularity
),
RankedSuppliers AS (
    SELECT *, RANK() OVER (ORDER BY total_supply_cost DESC) AS rank_supply_cost
    FROM SupplierDetails
)
SELECT 
    rc.c_name AS customer_name,
    rp.p_name AS product_name,
    rs.s_name AS supplier_name,
    rc.order_count,
    rc.total_spent,
    rp.total_quantity,
    rs.total_supply_cost
FROM 
    RankedCustomers rc
FULL OUTER JOIN RankedProducts rp ON rc.rank_spent = rp.rank_quantity
FULL OUTER JOIN RankedSuppliers rs ON rc.rank_spent = rs.rank_supply_cost
WHERE 
    rc.total_spent IS NOT NULL
    OR rp.total_quantity IS NOT NULL
    OR rs.total_supply_cost IS NOT NULL
ORDER BY 
    customer_name, product_name, supplier_name;
