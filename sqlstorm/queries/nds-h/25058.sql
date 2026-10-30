WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_nationkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' | Supplier: ', s.s_name, ' | Available Qty: ', ps.ps_availqty) AS part_supplier_details
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    psi.part_supplier_details,
    nr.n_name AS nation_name,
    nr.region_name,
    COUNT(*) AS total_supply_contracts
FROM PartSupplierInfo psi
JOIN NationRegion nr ON psi.s_nationkey = nr.n_nationkey
WHERE psi.ps_availqty > 10
GROUP BY psi.part_supplier_details, nr.n_name, nr.region_name
ORDER BY total_supply_contracts DESC, nr.region_name, psi.part_supplier_details;
