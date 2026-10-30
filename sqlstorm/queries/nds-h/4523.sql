WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM orders o
), SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), CustomerStatistics AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), CombinedData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.avg_order_value,
        cs.order_count,
        COALESCE(sc.total_supply_cost, 0) AS total_supply_cost
    FROM customer c
    LEFT JOIN CustomerStatistics cs ON c.c_custkey = cs.c_custkey
    LEFT JOIN SupplierCost sc ON sc.ps_partkey = (SELECT ps.ps_partkey 
                                                    FROM partsupp ps
                                                    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                                    WHERE l.l_orderkey = (SELECT o.o_orderkey
                                                                          FROM RankedOrders o
                                                                          WHERE o.total_price_rank = 1
                                                                          LIMIT 1)
                                                    LIMIT 1)
)

SELECT 
    cd.c_custkey,
    cd.c_name,
    cd.avg_order_value,
    cd.order_count,
    cd.total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY cd.avg_order_value DESC) as ranking
FROM CombinedData cd
WHERE cd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierCost)
AND cd.order_count > (SELECT COUNT(DISTINCT o.o_orderkey)/2 FROM orders o)
ORDER BY cd.avg_order_value DESC;
