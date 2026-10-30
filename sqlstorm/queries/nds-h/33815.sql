WITH  CustomerOrderTotals AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrderTotals c
    WHERE total_spent > 1000
),
SupplierAvgPrices AS (
    SELECT 
        ps.ps_suppkey, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
)
SELECT 
    rc.c_name, 
    rc.total_spent, 
    spp.avg_supply_cost,
    hpp.p_name,
    hpp.available_quantity
FROM RankedCustomers rc
JOIN SupplierAvgPrices spp ON rc.rank <= 10
JOIN HighValueParts hpp ON spp.ps_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
    WHERE l.l_quantity > 50
)
ORDER BY rc.total_spent DESC, spp.avg_supply_cost ASC;