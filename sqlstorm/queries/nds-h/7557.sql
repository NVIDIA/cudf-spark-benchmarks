
WITH SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_acctbal AS supplier_account_balance,
        ps.ps_supplycost AS supply_cost,
        (SELECT SUM(l.l_quantity) 
         FROM lineitem l 
         WHERE l.l_partkey = ps.ps_partkey) AS total_quantity_sold
    FROM 
        partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), RankSupplier AS (
    SELECT 
        spd.*,
        RANK() OVER (PARTITION BY spd.ps_partkey ORDER BY spd.total_quantity_sold DESC) AS rank_within_part
    FROM 
        SupplierPartDetails spd
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT spd.supplier_name) AS total_suppliers,
    AVG(spd.supplier_account_balance) AS avg_supplier_balance,
    SUM(spd.supply_cost) AS total_supply_cost
FROM 
    RankSupplier spd
    JOIN supplier s ON spd.supplier_name = s.s_name
    JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT spd.supplier_name) > 1
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
